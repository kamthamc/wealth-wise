import { useState, useRef, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Check } from 'lucide-react';
import { useInstitutions } from '@/hooks/useInstitutions';
import { Input } from '../Input';
import { Spinner } from '../Spinner';
import './InstitutionAutocomplete.css';

export interface InstitutionAutocompleteProps {
    id?: string;
    value: string;
    onChange: (value: string) => void;
    placeholder?: string;
    type?: 'bank' | 'insurance' | 'broker' | 'all';
    error?: string;
}

export function InstitutionAutocomplete({
    id,
    value,
    onChange,
    placeholder,
    type = 'all',
    error,
}: InstitutionAutocompleteProps) {
    const { t } = useTranslation();
    const { data: institutions, isLoading } = useInstitutions();
    const [isOpen, setIsOpen] = useState(false);
    const [searchTerm, setSearchTerm] = useState(value);
    const containerRef = useRef<HTMLDivElement>(null);

    // Sync internal search term with external value prop if it changes
    useEffect(() => {
        setSearchTerm(value);
    }, [value]);

    // Close dropdown when clicking outside
    useEffect(() => {
        function handleClickOutside(event: MouseEvent) {
            if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
                setIsOpen(false);
            }
        }
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    const filteredInstitutions = institutions?.filter((inst) => {
        // Filter by type if specified
        if (type !== 'all' && inst.type !== type && !(type === 'bank' && inst.type === 'other')) {
            // Allow 'other' types or mix if needed, but strict filtering is safer for now.
            // Actually 'bank' usually overlaps with 'broker' sometimes, but we stick to strict type if provided.
            // However, let's keep it simple: Filter by type if type is not all.
            if (inst.type !== type) return false;
        }

        // Filter by search term
        return inst.name.toLowerCase().includes(searchTerm.toLowerCase());
    }).slice(0, 10) || []; // Limit to 10 results

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const newValue = e.target.value;
        setSearchTerm(newValue);
        onChange(newValue);
        setIsOpen(true);
    };

    const handleSelect = (name: string) => {
        setSearchTerm(name);
        onChange(name);
        setIsOpen(false);
    };

    const handleFocus = () => {
        setIsOpen(true);
    };

    return (
        <div className="institution-autocomplete" ref={containerRef}>
            <Input
                id={id}
                value={searchTerm}
                onChange={handleInputChange}
                onFocus={handleFocus}
                placeholder={placeholder || t('common.selectInstitution')}
                error={error}
                autoComplete="off"
            />

            {isOpen && (searchTerm.length > 0 || isLoading) && (
                <ul className="institution-autocomplete__dropdown">
                    {isLoading ? (
                        <li className="institution-autocomplete__empty">
                            <Spinner size="sm" />
                        </li>
                    ) : filteredInstitutions.length > 0 ? (
                        filteredInstitutions.map((inst) => (
                            <li
                                key={inst.id}
                                className={`institution-autocomplete__item ${inst.name === value ? 'institution-autocomplete__item--selected' : ''
                                    }`}
                                onClick={() => handleSelect(inst.name)}
                            >
                                {inst.name}
                            </li>
                        ))
                    ) : (
                        <li className="institution-autocomplete__empty">
                            {t('common.noResultsFound')}
                        </li>
                    )}
                </ul>
            )}
        </div>
    );
}
